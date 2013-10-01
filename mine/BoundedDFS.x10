import x10.util.ArrayList;
import x10.util.HashSet;
import x10.util.HashMap;

public class BoundedDFS {
    static struct VertexDepth(vertex:Vertex, depth:Int) {
        def this(vertex:Vertex, depth:Int) {
            assert depth >= 0;
            property(vertex, depth);
        }
        def mustExplore() {
            val firstDepth = vertex.getDepth();
            return firstDepth == -1 || firstDepth > depth;
        }
        def siblings() {
            val newDepth = depth + 1;
            val result = new Array[VertexDepth](
                vertex.edges.size,
                (x:Int) => VertexDepth(vertex.edges(x), newDepth)
            );
            return result.values();
        }
        def visit() {
            return vertex.visit(depth);
        }
        public def hashCode() {return vertex.hashCode();}
        public def equals(obj:Any) {return vertex.equals(obj);}
    }
    
    def boundedDFS(vdepth:VertexDepth, depthBound:Int, outFrontier:HashSet[VertexDepth]) {
        if (vdepth.mustExplore()) {
            Console.OUT.println("Visiting: " + vdepth);
            if (vdepth.depth < depthBound) {
                vdepth.visit();
                outFrontier.remove(vdepth);
                for (sibling in vdepth.siblings()) {
                    boundedDFS(sibling, depthBound, outFrontier);
                }
            } else {
                outFrontier.add(vdepth);
            }
        }
    }
    
    def boundedDFSFromFrontier(frontier:HashSet[VertexDepth], currentBound:Int) {
        val outFrontier = new HashSet[VertexDepth]();
        for (v in frontier) {
            boundedDFS(v, currentBound, outFrontier);
        }
        return outFrontier;
    }
    
    def run(initial:Vertex, depthCutoff:Int, inc:Int) {
        val vdepth = new VertexDepth(initial, 0);
        var frontier:HashSet[VertexDepth] = new HashSet[VertexDepth]();
        frontier.add(vdepth);
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
    
    def run(vertex:Vertex) {
        run(vertex, 10, 2);
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
