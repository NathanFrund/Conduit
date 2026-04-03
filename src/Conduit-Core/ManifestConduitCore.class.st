"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestConduitCore',
	#superclass : 'PackageManifest',
	#category : 'Conduit-Core-Manifest',
	#package : 'Conduit-Core',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestConduitCore class >> ruleBadMessageRule2V1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGClassDefinition #(#ConduitWebAppDemo)) #'2026-04-03T15:47:03.69275-04:00') #(#(#RGMethodDefinition #(#TConduitRenderer #templateNamed: #false)) #'2026-04-03T15:48:54.818245-04:00') #(#(#RGMethodDefinition #(#TConduitRenderer #resolvePartials #false)) #'2026-04-03T15:49:27.31964-04:00') )
]

{ #category : 'code-critics' }
ManifestConduitCore class >> ruleLongMethodsRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'TConduitFreezable classTrait' #freeze: #true)) #'2026-04-03T15:47:52.209321-04:00') )
]

{ #category : 'code-critics' }
ManifestConduitCore class >> ruleReCyclomaticComplexityRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'TConduitFreezable classTrait' #freeze: #true)) #'2026-04-03T15:47:48.135639-04:00') )
]

{ #category : 'code-critics' }
ManifestConduitCore class >> ruleUncommonMessageSendRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGClassDefinition #(#ConduitWebAppDemo)) #'2026-04-03T15:47:16.524355-04:00') )
]
