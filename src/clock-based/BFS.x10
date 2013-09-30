import x10.util.Random;
import x10.util.ArrayList;
import x10.util.concurrent.AtomicBoolean;
public class BFS {
	
	static class V(id:Int) {
		var edges:Rail[V]=null;
		val visited = new AtomicBoolean();
		var origin:Int = -1;
	    def this(id:Int) {
	    	property(id);
	    }
	    def set(e:Rail[V]) {
	    	edges=e;
	    }
	    
	    def visit() {
	        return visited.compareAndSet(false, true);
	    }
	    
	    def isVisited() {
	        return visited.get();
	    }
	    
	    def edgeString() {
	    	if (edges==null) return "";
	    	var r:String = "";
	    	for (v in edges.values())
	    		r += " " + v.id;
	    	return r;
	    }
	    public def toString() = 
	    	"" + id + " (" + edgeString() + ") >";
	}

	public def run2(vertices:Array[V]) {
	    val verticesDepth = new Array[Int](vertices.size, (x:Int) => -1);
	    var frontier:ArrayList[V] = new ArrayList[V]();
	    frontier.add(vertices(0));
	    vertices(0).visit();
	    var depth:Int = 0;
        while (frontier.size() > 0) {
	        val nextFrontier = new ArrayList[V]();
	        finish {
                for (v in frontier) {
    	            async {
	                    if (v.visit()) {
	                        verticesDepth(v.id) = depth;
	                    }
	                }
	                for (s in v.edges.values()) {
	                    if (!s.isVisited()) nextFrontier.add(s);
                    }
	            }
            }
            frontier = nextFrontier;
            depth++;
        }
        return verticesDepth;
	}
	
	public static def main(args:Array[String](1)) {
		val N = Int.parseInt(args(0));
		Console.OUT.println("N=" + N);
		val vertices = new Rail[V](N, (i:Int)=> new V(i));
		val r = new Random();
		for (v in vertices.values()) {
			v.set(new Rail[V](r.nextInt(N / 2), (i:Int)=> vertices(r.nextInt(N))));
		}
		for (v in vertices.values()) {
			Console.OUT.println(v);
		}
		Console.OUT.println(new BFS().run2(vertices));
	}
}
