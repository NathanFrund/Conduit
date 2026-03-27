Class {
	#name : 'BaselineOfConduit',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfConduit',
	#package : 'BaselineOfConduit'
}

{ #category : 'baselines' }
BaselineOfConduit >> baseline: spec [

	<baseline>
	spec for: #common do: [ "1. External Dependencies"
			spec
				baseline: 'Mustache'
				with: [ spec repository: 'github://noha/mustache:v1.3/repository' ].

			"2. Your Packages"
			spec
				package: 'Conduit-Core' with: [ spec requires: #( 'Mustache' ) ];
				package: 'Conduit-Tests'
				with: [ spec requires: #( 'Conduit-Core' ) ].

			"3. Groups (Convenience for the user)"
			spec
				group: 'default' with: #( 'Conduit-Core' );
				group: 'Tests' with: #( 'ConduitCore-Tests' ) ]
]
