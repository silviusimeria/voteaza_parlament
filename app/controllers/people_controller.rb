class PeopleController < ApplicationController
  def show
    @person = Person.where(slug: params[:slug]).last # until we fix DB duplicates :)
    @nominations = @person.candidate_nominations.includes(:county, :party)
    @graph_data = fetch_connection_data(@person, params[:depth])

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "connections_graph",
          partial: "connections_graph",
          locals: { person: @person, graph_data: @graph_data }
        )
      end
    end
  end

  private

  def fetch_connection_data(person, depth = 1)
    depth = [depth.to_i, 3].min # Cap at depth 3
    depth = 1 if depth < 1

    nodes = []
    edges = []
    visited = Set.new

    collect_connections(person, depth, nodes, edges, visited)

    {
      nodes: nodes,
      edges: edges
    }
  end

  def collect_connections(person, depth, nodes, edges, visited, current_depth = 0)
    return if current_depth > depth || visited.include?(person.id)
    
    visited.add(person.id)
    
    # Add the person node
    nodes << {
      data: {
        id: "person_#{person.id}",
        label: person.name,
        isMain: current_depth.zero?
      }
    }

    # Get all connections
    person.connections.includes(:connected_person).each do |connection|
      next if visited.include?(connection.connected_person_id)

      # Add the connected person node
      connected_person = connection.connected_person
      
      # Add edge
      edges << {
        data: {
          id: "edge_#{connection.id}",
          source: "person_#{person.id}",
          target: "person_#{connected_person.id}",
          label: connection.relationship_type
        }
      }

      # Recursively collect connections if not at max depth
      if current_depth < depth
        collect_connections(
          connected_person, 
          depth, 
          nodes, 
          edges, 
          visited,
          current_depth + 1
        )
      end
    end
  end
end