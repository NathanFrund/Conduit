Class {
	#name : 'ConduitTraitWebAppTest',
	#superclass : 'TestCase',
	#category : 'Conduit-Tests',
	#package : 'Conduit-Tests'
}

{ #category : 'tests' }
ConduitTraitWebAppTest >> testPortSetter [
    | app |
    app := ConduitTraitWebApp new.
    app port: 9000.
    app startOn: nil.
    self assert: app port = 9000.
    app stop.
]

{ #category : 'tests' }
ConduitTraitWebAppTest >> testStartOnCreatesServer [
    | app |
    app := ConduitTraitWebApp new.
    app startOn: nil.
    self assert: app server notNil.
    app stop.

]

{ #category : 'tests' }
ConduitTraitWebAppTest >> testStopCleansUpServer [
    | app |
    app := ConduitTraitWebApp new.
    app startOn: nil.
    app stop.
    self assert: app server isNil.
]
