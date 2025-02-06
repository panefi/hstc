import json
import heapq
from typing import Dict, List, Tuple


class RouteFinder:
    def __init__(self, gate_data: List[Dict[str, str]]):
        """
        Initializes the RouteFinder with gate connections.
        """
        self.graph = self.build_graph(gate_data)

    def build_graph(self, gate_data: List[Dict[str, str]]) -> Dict[str, List[Tuple[str, float]]]:
        """
        Builds an adjacency list from the gate data.
        Returns:
            Dict[str, List[Tuple[str, float]]]: Adjacency list representation of the graph.
        """
        graph = {}
        for item in gate_data:
            id = item[0]
            connections = json.loads(item[2])
            graph[id] = []

            for connection in connections:
                target = connection['id']
                hu = float(connection['hu'])
                graph[id].append((target, hu))

        return graph

    def find_cheapest_route(self, start: str, end: str) -> Dict[str, any]:
        """
        Finds the cheapest route from start to end using Dijkstra's algorithm.
        """
        queue = []
        heapq.heappush(queue, (0, start, [start]))
        visited = set()

        while queue:
            current_distance, current_gate, path = heapq.heappop(queue)

            if current_gate == end:
                return {"distance": current_distance, "path": path}

            if current_gate in visited:
                continue

            visited.add(current_gate)

            for neighbor, distance in self.graph.get(current_gate, []):
                if neighbor not in visited:
                    heapq.heappush(queue, (current_distance + distance, neighbor, path + [neighbor]))
        return {"distance": float('inf'), "path": []}  # No route found 