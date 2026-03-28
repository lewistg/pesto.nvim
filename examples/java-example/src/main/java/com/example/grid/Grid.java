package com.example.aoc.grid;

import java.util.Set;
import java.util.HashSet;

public class Grid {
    private int width;
    private int height;

    public static record Point(int i, int j) {}

    public Grid(int width, int height) {
        if (width <= 0 || height <= 0) {
            throw new IllegalArgumentException("Width and height must be positive");
        }
        this.width = width;
        this.height = height;
    }

    public int getWidth() {
        return this.width;
    }

    public int getHeight() {
        return this.height;
    }

    public Set<Point> getNeighbors(Point point) {
        Set<Point> neighbors = new HashSet<Point>();
        for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
            int i = point.i + rowOffset;
            if (rowOffset != 0 && i >= 0 && i < height) {
                neighbors.add(new Point(i, point.j));
            }
        }
        for (int colOffset = -1; colOffset <= 1; colOffset++) {
            int j = point.j + colOffset;
            if (colOffset != 0 && j >= 0 && j < width) {
                neighbors.add(new Point(point.i, j));
            }
        }
        return neighbors;
    }
}
