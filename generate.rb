# https://github.com/ruby/ruby/blob/8be3f74e19492a313c930e031254116df3994078/parse.y#L754
KEYWORDS = %w[
	class module def undef begin rescue ensure end if unless then elsif else case when while until
  for break next redo retry in do do_cond do_block do_LAMBDA return yield super self nil true
	false and or not alias defined BEGIN END __LINE__ __FILE__ __ENCODING__
]

Node = Struct.new(:depth, :variable_names, :children) do
  def to_code(stream='')
    indentation = '  ' * depth
    name        = "#{depth}: #{variable_names.join(', ')}"
    namespace   = 'RSpec.' if depth==0

    stream << "#{indentation}#{namespace}describe #{name.inspect} do\n"
    variable_names.each_with_index.each { |name, index|
      value = (index == variable_names.length-1 ? index : 'super()' )
      stream << "#{indentation+'  '}let(:#{name}) { #{value} }\n"
    }
    stream << "#{indentation}  example { #{variable_names.join '; '} }\n"
    children.each { |child| child.to_code stream }
    stream << "#{indentation}end\n"
  end
end

def tree(depth, cutoff, next_variable_name, variable_names)
  begin
    var_name = next_variable_name.next
  end while KEYWORDS.include?(var_name)

  Node.new depth, variable_names, (cutoff-depth).times.map {
    tree(depth+1, cutoff, next_variable_name, [*variable_names, var_name])
  }
end

next_variable_name = ('a'.."#{'z'*50}").each # "infinite" loop of sequential variable names

depth, outfile = ARGV
depth   = (depth || '2').to_i
outfile &&= File.open(outfile, 'w')
outfile ||= $stdout

tree(0, depth, next_variable_name, []).to_code(outfile)


# >> RSpec.describe "0: " do
# >>   example {  }
# >>   describe "1: a" do
# >>     let(:a) { 0 }
# >>     example { a }
# >>     describe "2: a, b" do
# >>       let(:a) { super() }
# >>       let(:b) { 1 }
# >>       example { a; b }
# >>     end
# >>   end
# >>   describe "1: a" do
# >>     let(:a) { 0 }
# >>     example { a }
# >>     describe "2: a, d" do
# >>       let(:a) { super() }
# >>       let(:d) { 1 }
# >>       example { a; d }
# >>     end
# >>   end
# >> end
