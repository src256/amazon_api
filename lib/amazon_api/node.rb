module AmazonApi
  class Node
    def self.create(ecs_node)
      node = Node.new
      node.browse_node_id = ecs_node.get('BrowseNodeId')
      node.name = ecs_node.get('Name')
      node
    end

    def initialize
    end

    attr_accessor :browse_node_id, :name
  end
end