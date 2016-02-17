namespace :workflow do
  desc 'create workflow diagram for a class'
  task :diagrams, [:class, :path] => :environment do |_t, args|
    class_name = args[:class]
    path = args[:path] || 'tmp'

    file_path = create_workflow_diagram(
      class_name.gsub("::", ""),
      Visiflow::Step.create_steps(class_name.constantize.steps),
      path)
    `open #{file_path}`
  end
end

# rubocop:disable MethodLength
def create_workflow_diagram(workflow_name, steps, target_dir = '.',
  graph_options = 'rankdir="TD", size="7,11.6", ratio="fill"'
)
  fname = File.join(target_dir, "#{workflow_name}")
  File.open("#{fname}.dot", 'w') do |file|
    file.puts %(
digraph #{workflow_name} {
  graph [#{graph_options}];
  node [shape=box];
  edge [len=1];
        )
    steps.each_pair do |step, outcomes|
      normalized_step = normalize_step(step)
      file.puts %(        "#{normalized_step}" [label="#{normalized_step}"];      )

      outcomes.step_map.each_pair do |response, next_step|
        file.puts %(          "#{normalized_step}" -> "#{normalize_step(next_step)}" \
                  [label="#{normalize_step(response)}"];        )
      end
    end
    file.puts '}'
    file.puts
  end
  `dot -Tpdf -o'#{fname}.pdf' '#{fname}.dot'`
  "#{fname}.pdf"
end
# rubocop:enable MethodLength

def normalize_step(step)
  step.to_s.gsub('?', '').titleize.gsub(/_/, ' ')
end

def normalize_response(_response)
  step.to_s.gsub('?', '')
end
