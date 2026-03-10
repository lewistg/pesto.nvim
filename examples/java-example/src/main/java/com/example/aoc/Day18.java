package com.example.aoc;

import com.example.aoc.grid.Grid;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A solution to day 18 part 1 of Advent of Code 2024 [1].
 *
 * [1]: https://adventofcode.com/2024/day/18
 */
public class Day18 {
    private static final Pattern POINT_PATTERN = Pattern.compile("^(\\d+),(\\d+)\s*$");

    private int findShortestPath(int mapSize, Set<Grid.Point> corruptLocations) {
        // Note: In this case we can find the shortest distance using a simple breadth-first search

        Grid grid = new Grid(mapSize, mapSize);

        Set<Grid.Point> points = new HashSet<Grid.Point>();
        Set<Grid.Point> visitedPoints = new HashSet<Grid.Point>();

        Grid.Point startPoint = new Grid.Point(0, 0);
        Grid.Point endPoint = new Grid.Point(grid.getHeight() - 1, grid.getWidth() - 1);

        points.add(startPoint);
        int distance = 0;

        while (!points.isEmpty()) {
            for (Grid.Point point : points) {
                if (point.equals(endPoint)) {
                    return distance;
                }
                visitedPoints.add(point);
            }

            distance += 1;

            Set<Grid.Point> nextPoints = new HashSet<Grid.Point>();
            for (Grid.Point point : points) {
                for (Grid.Point neighborPoint : grid.getNeighbors(point)) {
                    if (!visitedPoints.contains(neighborPoint) && !corruptLocations.contains(neighborPoint)) {
                        nextPoints.add(neighborPoint);
                    }
                }
            }
            points = nextPoints;
        }

        return 0;
    }

    private List<Grid.Point> getCorruptPoints(String locationsFile) throws IOException {
        List<Grid.Point> points = new ArrayList<Grid.Point>();
        List<String> lines = Files.readAllLines(Path.of(locationsFile));
        for (String line : lines) {
            Matcher match = Day18.POINT_PATTERN.matcher(line);
            if (!match.find()) {
                throw new IllegalArgumentException("Invalid line: " + line);
            }
            int i = Integer.parseInt(match.group(2));
            int j = Integer.parseInt(match.group(1));
            points.add(new Grid.Point(i, j));
        }
        return points;
    }

    public static void main(String args[]) throws Exception {
        if (args.length < 1) {
            throw new Exception("Missing input file argument");
        }

        Day18 day18 = new Day18();

        int mapSize = 71;
        int byteLimit = 1024;

        List<Grid.Point> corruptPoints = day18.getCorruptPoints(args[0]);
        int shortestDistance = day18.findShortestPath(mapSize, new HashSet<>(corruptPoints.subList(0, byteLimit)));
        System.out.println("shortest distance: " + shortestDistance);
    }
}
