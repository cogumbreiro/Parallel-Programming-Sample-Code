import x10.util.Stack;
class DFS {
    def run(vertex:Vertex) {
        val elements = new Stack[Vertex]();
        elements.push(vertex);
        while (elements.size() > 0) {
            val currVertex = elements.pop();
            Console.OUT.println("Visiting: " + currVertex.id);
            for(p in 1..currVertex.edges.size) {
                val sibling = currVertex.edges(currVertex.edges.size - p);
                if (sibling.visit()) {
                    elements.push(sibling);
                }
            }
        }
    }
	public static def main(args:Array[String](1)) {
		val N = Int.parseInt(args(0));
		Console.OUT.println("N=" + N);
		val vertices = Vertex.makeGraph(N);
		for (v in vertices.values()) {
			Console.OUT.println(""+v);
		}
		Console.OUT.println("Searching...");
		new DFS().run(vertices(0));
	}
}
