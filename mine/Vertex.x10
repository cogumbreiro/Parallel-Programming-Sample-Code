import x10.util.concurrent.AtomicInteger;
import x10.util.Random;
import x10.util.HashSet;

class Vertex(id:Int) {
    val visited = new AtomicInteger(-1);
	var edges:Array[Vertex]=null;
    def this(id:Int) {
    	property(id);
    }
    def set(e:Array[Vertex]) {
    	edges=e;
    }
    
    def visit(depth:Int) {
        return visited.compareAndSet(-1, depth);
    }
    
    def visit() {
        return visit(0);
    }
    
    def isVisited() {
        return visited.get() != -1;
    }
    
    def getDepth() {
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
    	"Vertex(id=" + id + ", depth=" + visited + ", edges=[" + edgeString() + "])";
    
    public static def makeGraph(size:Int) {
		val vertices = new Array[Vertex](size, (i:Int)=> new Vertex(i));
		val r = new Random();
		for (v in vertices.values()) {
			val total = r.nextInt(size);
			val neighbours = new HashSet[Int](total);
			for (_ in 1..total) {
                neighbours.add(r.nextInt(size));
			}
			val iter = neighbours.iterator();
		    v.set(new Array[Vertex](neighbours.size(),
		        (x:Int)=>vertices(iter.next())));
		}
		return vertices;
    }
}

