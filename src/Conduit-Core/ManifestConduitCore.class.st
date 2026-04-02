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
	^ #(#(#(#RGMethodDefinition #(#ConduitWebApp #resolvePartials #false)) #'2026-03-26T17:01:11.203836-04:00') )
]

{ #category : 'code-critics' }
ManifestConduitCore class >> ruleCascadedNextPutAllsRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#ConduitTraitWebApp #serveFrozenAsset: #false)) #'2026-04-02T10:20:56.334068-04:00') #(#(#RGMethodDefinition #(#ConduitTraitWebApp #renderFragment:context: #false)) #'2026-04-02T10:23:31.146553-04:00') )
]

{ #category : 'code-critics' }
ManifestConduitCore class >> ruleUncommonMessageSendRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#ConduitTraitWebApp #configureRoutes #false)) #'2026-04-02T10:21:29.713394-04:00') #(#(#RGMethodDefinition #(#ConduitTraitWebApp #configureStaticAssets #false)) #'2026-04-02T10:21:42.417419-04:00') )
]
