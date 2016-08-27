Dir["#{File.expand_path('../',  __FILE__)}/ruby2lua/**/*.rb"].uniq.each do |filename|
  require filename if filename.include? ".rb"
end

require 'pp'

module Ruby2Lua
  def self.compile!(code)
    sexp = RubyParser.new.parse(code)
    codegen = CodeGenVisitor.new
    pp sexp
    ASTTransform.new.apply(sexp).accept(codegen)
    codegen.to_s
  end
end
