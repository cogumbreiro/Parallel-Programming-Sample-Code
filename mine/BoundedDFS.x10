import x10.util.ArrayList;
import x10.util.HashSet;
import x10.util.HashMap;

public class BoundedDFS {
    val doneStates = new HashMap[Vertex,Int]();
    val depth = new HashMap[Vertex,Int]();

    def mustExplore(vertex:Vertex) {
        val doneState = doneStates(vertex);
        if (doneState != null && doneState() <= depth(vertex).value) {
            return false;
        }
        return true;
    }
    
    def boundedDFS(vertex:Vertex, depthBound:Int, outFrontier:HashSet[Vertex]) {
        if (mustExplore(vertex)) {
            Console.OUT.println("Visiting: " + vertex);
            val vertexDepth = depth(vertex).value;
            if (vertexDepth < depthBound) {
                doneStates.put(vertex, vertexDepth);
                outFrontier.remove(vertex);
                for (sibling in vertex.edges.values()) {
                    depth.put(sibling, vertexDepth + 1);
                    boundedDFS(sibling, depthBound, outFrontier);
                }
            } else {
                outFrontier.add(vertex);
            }
        }
    }
    
    def iterBoundedDFS(initial:Vertex, depthCutoff:Int, inc:Int) {
        depth.put(initial, 0);
        var frontier:HashSet[Vertex] = new HashSet[Vertex]();
        frontier.add(initial);
        var currentBound:Int = inc;
        while (currentBound <= depthCutoff) {
            val newFrontier = boundedDFSFromFrontier(frontier, currentBound);
            if (newFrontier.isEmpty()) {
                return true;
            }
            currentBound += inc;
            frontier = newFrontier;
        }
        return false;
    }
    
    def boundedDFSFromFrontier(frontier:HashSet[Vertex], currentBound:Int) {
        val outFrontier = new HashSet[Vertex]();
        for (v in frontier) {
            boundedDFS(v, currentBound, outFrontier);
        }
        return outFrontier;
    }
    
    def run(vertex:Vertex) {
        iterBoundedDFS(vertex, 10, 2);
    }
    
	public static def main(args:Array[String](1)) {
		val N = Int.parseInt(args(0));
		Console.OUT.println("N=" + N);
		val vertices = Vertex.makeGraph(N);
		for (v in vertices.values()) {
			Console.OUT.println(""+v);
		}
		Console.OUT.println("Searching...");
		new BoundedDFS().run(vertices(0));
	}
}
