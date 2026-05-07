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
TConduitRendererTest >> testResolvePartialsWithEscapedUnderscore [
    "Verify that resolvePartials correctly un-escapes frozen method selectors
     containing double underscores back into path keys with single underscores."
    | renderer partials |
    renderer := TestRenderer new.
    renderer conduit: nil.

    "Add a frozen method on the instance side, following the escaping convention"
    TestRenderer compile: 'frozenTemplatepartials_register__form ^ ''<div class="error">{{error}}</div>'''.

    partials := renderer resolvePartials.
    self assert: (partials includesKey: 'partials/register_form').
    self assert: (partials includesKey: 'index').   "pre‑existing frozen method still works"

    "Clean up"
    TestRenderer removeSelector: #frozenTemplatepartials_register__form.
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
