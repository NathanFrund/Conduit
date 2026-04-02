Class {
	#name : 'ConduitTest',
	#superclass : 'TestCase',
	#category : 'Conduit-Tests',
	#package : 'Conduit-Tests'
}

{ #category : 'tests' }
ConduitTest >> testPointingAtCreatesRootFolder [
    | conduit |
    conduit := Conduit pointingAt: FileLocator temp asString.
    self assert: conduit rootFolder notNil.
]

{ #category : 'tests' }
ConduitTest >> testRegistryStartsEmpty [
    | conduit |
    conduit := Conduit new.
    self assert: conduit registry isEmpty.
]

{ #category : 'tests' }
ConduitTest >> testSyncFilesAddsMustacheTemplates [
    | testDir conduit tempFile template |
    "Create a unique test directory"
    testDir := FileLocator temp / ('conduit-test-', Time now asSeconds asString).
    testDir ensureCreateDirectory.
    
    "Create conduit pointing to test directory"
    conduit := Conduit pointingAt: testDir pathString.
    
    "Create a temporary .mustache file"
    tempFile := testDir / 'test.mustache'.
    tempFile writeStreamDo: [ :stream | 
        stream nextPutAll: 'Hello {{name}}!' ].
    
    "Sync files - should discover the new file"
    conduit syncFiles.
    
    "Verify the template was added to registry"
    self assert: (conduit registry includesKey: 'test').
    
    "Verify the template content is correct"
    template := conduit registry at: 'test'.
    self assert: (template value: { 'name' -> 'World' } asDictionary) 
        equals: 'Hello World!'.
    
    "Clean up"
    testDir deleteAll.
]

{ #category : 'tests' }
ConduitTest >> testSyncFilesRemovesDeletedFiles [
    | testDir conduit tempFile |
    "Create a dedicated test directory"
    testDir := FileLocator temp / ('conduit-test-', Time now asSeconds asString).
    testDir ensureCreateDirectory.
    
    conduit := Conduit pointingAt: testDir pathString.
    
    "Create file and verify it's in registry"
    tempFile := testDir / 'test.mustache'.
    tempFile writeStreamDo: [ :stream | stream nextPutAll: 'content' ].
    conduit syncFiles.
    self assert: (conduit registry includesKey: 'test').
    
    "Delete file and verify it's removed from registry"
    tempFile ensureDelete.
    conduit syncFiles.
    self deny: (conduit registry includesKey: 'test').
    
    "Clean up"
    testDir deleteAll.
]
