Class {
	#name : 'TestRenderer',
	#superclass : 'Object',
	#traits : 'TConduitRenderer',
	#classTraits : 'TConduitRenderer classTrait',
	#instVars : [
		'conduit'
	],
	#category : 'Conduit-Tests',
	#package : 'Conduit-Tests'
}

{ #category : 'accessing' }
TestRenderer >> conduit [
    ^ conduit
]

{ #category : 'accessing' }
TestRenderer >> conduit: anObject [
    conduit := anObject
]

{ #category : 'frozen-templates' }
TestRenderer >> frozenTemplateindex [
    ^ '<h1>Hello</h1>'
]

{ #category : 'frozen-templates' }
TestRenderer >> frozenTemplatelayout [
    ^ '<html>{{content}}</html>'
]
