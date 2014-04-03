module SyntaxHelpers
  # Declare the code that is under test.
  #
  # :call-seq:
  #   act(:named_result, &block)
  #   act(&block)
  #
  def act(*args, &block)
    if args.first.is_a?(Symbol)
      let!(args.first, &block)
    else
      before(&block)
    end
  end
end
