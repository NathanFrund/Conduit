Class {
	#name : 'ConduitWebAppTest',
	#superclass : 'TestCase',
	#instVars : [
		'app',
		'testRoot'
	],
	#category : 'ConduitCore-Tests',
	#package : 'ConduitCore-Tests'
}

{ #category : 'running' }
ConduitWebAppTest >> setUp [
    super setUp.
    
    "1. Create the sandbox"
    testRoot := (FileLocator temp / 'conduit-test-assets') ensureCreateDirectory.
    
    "2. Initialize the App and link it to the path"
    app := ConduitWebApp startOn: testRoot.
    
    "Note: If startOn: isn't enough, we might need a manual scan in the test itself."
]

{ #category : 'running' }
ConduitWebAppTest >> tearDown [
	"Clean up the sandbox after every test"

	testRoot isDirectory ifTrue: [ testRoot deleteAll ].
	super tearDown
]

{ #category : 'tests' }
ConduitWebAppTest >> testFrozenFallback [
    | template result |
    app rootPath: nil.
    
    "1. Simulate a frozen asset"
    ConduitWebApp instanceSide 
        compile: 'frozenTemplateTest ^ ''Welcome {{user}}''' 
        classified: 'content-templates'.
        
    [ 
        "2. Retrieve the template through your engine logic"
        template := app templateNamed: 'test'.
        
        "3. Trigger the evaluation using the 'value:' selector"
        result := template value: { 'user' -> 'Guest' } asDictionary.
        
        self assert: result equals: 'Welcome Guest' 
    ] ensure: [ 
        "4. Cleanup the image so we don't pollute your 'content-templates' protocol"
        ConduitWebApp instanceSide removeSelector: #frozenTemplateTest 
    ].
]

{ #category : 'tests' }
ConduitWebAppTest >> testTemplateReadFromDisk [
    | file content template result |
    content := '<h1>Hello from Disk</h1>'.
    
    "1. Write the file to the temp directory"
    file := testRoot / 'index.mustache'.
    file writeStreamDo: [ :s | s nextPutAll: content ].

    "2. Tell the conduit to synchronize with the filesystem"
    app conduit syncFiles. 

    "3. Retrieve and verify"
    template := app templateNamed: 'index'.
    
    self assert: template isNotNil.
    
    "Using the 'value:' selector we found earlier"
    result := template value: Dictionary new.
    self assert: result equals: content.
]
