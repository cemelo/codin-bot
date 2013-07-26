# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "codinbot"
  s.version     = "0.0.1"
  s.authors     = ["Carlos Eduardo Melo"]
  s.email       = ["carlos.e.melo@planejamento.gov.br"]
  s.homepage    = "https://www.siop.planejamento.gov.br"
  s.summary     = %q{Robô com funções de apoio ao processo da CODIN.}
  s.description = s.summary

  s.rubyforge_project = "codinbot"

  s.require_paths = [".", "lib"]

  s.add_dependency "cinch"
  s.add_dependency "fortune_gem"
end