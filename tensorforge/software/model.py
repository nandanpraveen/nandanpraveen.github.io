"""Train and quantize a 4→8→3 ReLU network on a stratified Iris split."""
import csv
import math
import random
from pathlib import Path
from statistics import fmean, pstdev

ROOT = Path(__file__).resolve().parents[1]
FEATURES, HIDDEN, CLASSES = 4, 8, 3
FEATURE_SHIFT, WEIGHT_SHIFT = 5, 6
SEED = 1729


def argmax(items):
    return max(range(len(items)), key=items.__getitem__)


def clip8(value):
    return max(-128, min(127, value))


def read_split():
    with (ROOT / "datasets" / "iris.csv").open(newline="") as file:
        rows = csv.reader(file)
        next(rows)
        samples = [(list(map(float, row[:4])), int(row[4])) for row in rows if row]
    rng = random.Random(SEED)
    train, test = [], []
    for label in range(CLASSES):
        group = [sample for sample in samples if sample[1] == label]
        rng.shuffle(group)
        train.extend(group[:40])
        test.extend(group[40:])
    means = [fmean(col) for col in zip(*(x for x, _ in train))]
    stds = [pstdev(col) for col in zip(*(x for x, _ in train))]

    def normalize(samples):
        return [
            ([(x[i] - means[i]) / stds[i] for i in range(FEATURES)], label)
            for x, label in samples
        ]

    return normalize(train), normalize(test), means, stds


def affine(x, weights, biases):
    return [sum(a * b for a, b in zip(x, col)) + bias for col, bias in zip(zip(*weights), biases)]


def train_model():
    train, test, means, stds = read_split()
    rng = random.Random(SEED)
    w1 = [[rng.uniform(-0.4, 0.4) for _ in range(HIDDEN)] for _ in range(FEATURES)]
    w2 = [[rng.uniform(-0.4, 0.4) for _ in range(CLASSES)] for _ in range(HIDDEN)]
    b1, b2 = [0.0] * HIDDEN, [0.0] * CLASSES
    for epoch in range(100):
        rng.shuffle(train)
        lr = 0.025 / (1 + epoch / 50)
        for x, label in train:
            hidden = [max(0.0, value) for value in affine(x, w1, b1)]
            logits = affine(hidden, w2, b2)
            exp = [math.exp(value - max(logits)) for value in logits]
            grad2 = [value / sum(exp) - (index == label) for index, value in enumerate(exp)]
            grad1 = [
                (sum(w2[j][c] * grad2[c] for c in range(CLASSES)) if hidden[j] > 0 else 0)
                for j in range(HIDDEN)
            ]
            for c, grad in enumerate(grad2):
                b2[c] -= lr * grad
                for j, activation in enumerate(hidden):
                    w2[j][c] -= lr * activation * grad
            for j, grad in enumerate(grad1):
                b1[j] -= lr * grad
                for i, activation in enumerate(x):
                    w1[i][j] -= lr * activation * grad

    def quantize_weights(weights):
        return [[clip8(round(x * (1 << WEIGHT_SHIFT))) for x in row] for row in weights]

    def quantize_biases(biases):
        return [round(x * (1 << (FEATURE_SHIFT + WEIGHT_SHIFT))) for x in biases]

    network = {
        "feature_means": means,
        "feature_stds": stds,
        "feature_shift": FEATURE_SHIFT,
        "weight_shift": WEIGHT_SHIFT,
        "w1": quantize_weights(w1),
        "b1": quantize_biases(b1),
        "w2": quantize_weights(w2),
        "b2": quantize_biases(b2),
    }
    floating = [argmax(affine([max(0.0, x) for x in affine(row, w1, b1)], w2, b2)) for row, _ in test]
    inputs = [[clip8(round(value * (1 << FEATURE_SHIFT))) for value in row] for row, _ in test]
    return network, inputs, [label for _, label in test], floating
