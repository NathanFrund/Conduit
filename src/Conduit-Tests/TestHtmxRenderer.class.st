Class {
	#name : 'TestHtmxRenderer',
	#superclass : 'Object',
	#traits : 'THtmxRenderer + TConduitRenderer',
	#classTraits : 'THtmxRenderer classTrait + TConduitRenderer classTrait',
	#instVars : [
		'conduit'
	],
	#category : 'Conduit-Tests',
	#package : 'Conduit-Tests'
}

{ #category : 'accessing' }
TestHtmxRenderer >> conduit [
	^ conduit
]

{ #category : 'rendering' }
TestHtmxRenderer >> frozenTemplateclicked__response [
    ^ '<span>Clicked at {{time}}</span>'
]

{ #category : 'rendering' }
TestHtmxRenderer >> renderPage: aPageName context: aDictionary [
    ^ 'Full page: ', aPageName
]
