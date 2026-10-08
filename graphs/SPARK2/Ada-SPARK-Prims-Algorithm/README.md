# Prim minimum spanning tree in bounded SPARK

The matrix and selected parent array have fixed capacity.

Each step adds the unused node with the smallest key (ties go to the lowest
node number), so the parent array is a minimum spanning tree rooted at node
1 for a connected graph. Nodes that node 1 cannot reach keep parent 1.
Absent edges have weight `Infinity`.
