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
THtmxRendererTest >> testRenderCallsRenderFragmentForHtmxRequest [
    | renderer request result |
    renderer := TestHtmxRenderer new.
    request := ZnRequest get: '/' asZnUrl.
    request headers at: 'HX-Request' put: 'true'.
    
    result := renderer render: 'clicked_response' request: request context: Dictionary new.
    self assert: (result includesSubstring: 'Clicked at').
]

{ #category : 'tests' }
THtmxRendererTest >> testRenderCallsRenderPageForNormalRequest [
    | renderer request result |
    renderer := TestHtmxRenderer new.
    request := ZnRequest get: '/' asZnUrl.
    
    result := renderer render: 'index' request: request context: Dictionary new.
    self assert: (result includesSubstring: 'Full page').
]
