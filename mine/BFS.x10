import x10.util.Random;
import x10.util.ArrayList;
public class BFS {
	
	def compactFrontier(frontier:Array[Array[Vertex]]) {
	    var count:Int = 0;
        for (part in frontier.values()) {
            count += part.size;
        }
	    val newFrontier = new Array[Vertex](count);
	    count = 0;
        for (part in frontier.values()) {
            Array.copy(part, 0, newFrontier, count, part.size);
            count += part.size;
        }
	    return newFrontier;
	}
	
	def run(toVisit:Vertex) {
	    var frontier:Array[Vertex] = new Array[Vertex](1, (x:Int) => toVisit);
	    toVisit.visit();
	    
	    while (frontier.size > 0) {
	        val nextFrontier = new Array[Array[Vertex]](frontier.size);
	        finish for (p in frontier) async {
	            val vertex = frontier(p);
	            val myFrontier = new ArrayList[Vertex](vertex.edges.size);
	            for (sibling in vertex.edges.values()) {
	                if (sibling.visit()) {
	                    myFrontier.add(sibling);
	                }
	            }
	            nextFrontier(p) = myFrontier.toArray();
	        }
	        frontier = compactFrontier(nextFrontier);
	    }
	}
	
	public static def main(args:Array[String](1)) {
		val N = Int.parseInt(args(0));
		Console.OUT.println("N=" + N);
		val vertices = Vertex.makeGraph(N);
		Console.OUT.println("Starting mark.");
		new BFS().run(vertices(0));
		for (v in vertices) {
			Console.OUT.println(""+v);
		}
	}
}
