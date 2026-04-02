Class {
	#name : 'TConduitRendererTest',
	#superclass : 'TestCase',
	#category : 'Conduit-Tests',
	#package : 'Conduit-Tests'
}

{ #category : 'tests' }
TConduitRendererTest >> testRenderPageUsesLayout [
    | renderer result |
    renderer := TestRenderer new.
    renderer conduit: nil.
    
    result := renderer renderPage: 'index'.
    self assert: (result includesSubstring: '<html>').
    self assert: (result includesSubstring: 'Hello').
]

{ #category : 'tests' }
TConduitRendererTest >> testResolvePartialsBuildsFromFrozenMethods [
    | renderer partials |
    renderer := TestRenderer new.
    renderer conduit: nil.
    
    partials := renderer resolvePartials.
    self assert: (partials includesKey: 'index').
    self assert: (partials includesKey: 'layout').
]

{ #category : 'tests' }
TConduitRendererTest >> testTemplateNamedFindsFrozenMethod [
    | renderer |
    renderer := TestRenderer new.
    renderer conduit: nil.
    
    self assert: (renderer templateNamed: 'index') notNil.
]

{ #category : 'tests' }
TConduitRendererTest >> testTemplateNamedReturnsNilForMissing [
    | renderer |
    renderer := TestRenderer new.
    renderer conduit: nil.
    
    self assert: (renderer templateNamed: 'missing') isNil.
]
