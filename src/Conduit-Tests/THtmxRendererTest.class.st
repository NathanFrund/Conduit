Class {
	#name : 'THtmxRendererTest',
	#superclass : 'TestCase',
	#category : 'Conduit-Tests',
	#package : 'Conduit-Tests'
}

{ #category : 'tests' }
THtmxRendererTest >> testIsHtmxRequestReturnsFalseForNormalRequest [
    | renderer request |
    renderer := TestHtmxRenderer new.
    request := ZnRequest get: '/' asZnUrl.
    
    self deny: (renderer isHtmxRequest: request).
]

{ #category : 'tests' }
THtmxRendererTest >> testIsHtmxRequestReturnsTrueForHtmxHeader [
    | renderer request |
    renderer := TestHtmxRenderer new.
    request := ZnRequest get: '/' asZnUrl.
    request headers at: 'HX-Request' put: 'true'.
    
    self assert: (renderer isHtmxRequest: request).
]

{ #category : 'tests' }
THtmxRendererTest >> testRenderAuto [
    | renderer normalRequest htmxRequest |
    renderer := TestHtmxRenderer new.
    normalRequest := ZnRequest get: '/' asZnUrl.
    htmxRequest := ZnRequest get: '/' asZnUrl.
    htmxRequest headers at: 'HX-Request' put: 'true'.
    
    "Without HTMX header -> full page"
    self assert: (renderer renderAuto: 'clicked_response' request: normalRequest context: Dictionary new)
        equals: 'Full page: clicked_response'.
    
    "With HTMX header -> fragment"
    self assert: ((renderer renderAuto: 'clicked_response' request: htmxRequest context: Dictionary new)
        includesSubstring: 'Clicked at').
    
    "Nil request -> full page (safe default)"
    self assert: (renderer renderAuto: 'clicked_response' request: nil context: Dictionary new)
        equals: 'Full page: clicked_response'.
]

{ #category : 'tests' }
THtmxRendererTest >> testRenderCallsRenderFragmentForHtmxRequest [
    | renderer result |
    renderer := TestHtmxRenderer new.
    result := renderer renderFragment: 'clicked_response' context: Dictionary new.
    self assert: (result includesSubstring: 'Clicked at').

]

{ #category : 'tests' }
THtmxRendererTest >> testRenderCallsRenderPageForNormalRequest [
    | renderer result |
    renderer := TestHtmxRenderer new.
    result := renderer renderPage: 'index' context: Dictionary new.
    self assert: (result includesSubstring: 'Full page').
]
