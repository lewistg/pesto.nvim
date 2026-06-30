package com.example.grid;

import com.example.aoc.grid.Grid;
import static com.example.aoc.grid.Grid.Point;
import java.util.Set;
import static org.junit.jupiter.api.Assertions.assertEquals;
import org.junit.jupiter.api.Test;

public class GridTest {

    @Test
    void getNeighbors() {
        Grid grid = new Grid(8, 8);
        Point point = new Point(1, 7);

        Set<Point> actualNeighbors = grid.getNeighbors(point);
        Set<Point> expectedNeighors = Set.of(new Point(0, 7), new Point(2, 7), new Point(1, 6));

        assertEquals(actualNeighbors, expectedNeighors);
    }
}
