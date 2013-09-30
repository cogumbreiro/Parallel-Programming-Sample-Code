import x10.util.concurrent.AtomicBoolean;
import x10.util.Random;
import x10.util.HashSet;

class Vertex(id:Int) {
    val visited = new AtomicBoolean(false);
	var edges:Array[Vertex]=null;
	var out:Int=-1;
    def this(id:Int) {
    	property(id);
    }
    def set(e:Array[Vertex]) {
    	edges=e;
    }
    
    def visit() {
        return visited.compareAndSet(false, true);
    }
    
    def edgeString() {
    	if (edges==null) return "";
    	var r:String = "";
    	for (v in edges.values())
    		r += " " + v.id;
    	return r;
    }
    public def toString() = 
    	"" + id + " (" + edgeString() + ") > " + out;
    
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

