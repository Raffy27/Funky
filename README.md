# Funky
An attempt at reproducing Func-In Technology in Delphi. Based on the earlier works of Counterstrikewi, Abhe, and Steve10120. See [**this post**](http://www.delphibasics.info/home/delphibasicscounterstrikewireleases/func-indelphiexample) for details on the technique.

## Builder
The Builder creates two files: *File.bin* and *Msg.bin*. These files contain the actual bytecode and the necessary imports of their respective functions, in the following format:

```Header - Size of code - Code - Number of imports - [Size of import - Import]```

An advantage of this method is the fact that this code can be compressed, and thus it may benefit systems revolving around remote administration.

## Stub
The Stub loads the two files created by the Builder, parses them, loads their code into memory and executes it.

## Notes
To see additional information such as code size and allocation address, define the *DEBUG* compiler directive or use a general debugging profile when compiling the code.

Functions that make use of this technique must not directly contain strings or constants that are not represented in bytecode, these must be passed to them separately as Imports. All other functions referenced must be in scope, you have to manually import them from their respective libraries. See the source code of the Builder for an example.

### The sample files
*File.bin* contains instructions that create a new file called *Test.txt* in the current working directory of the process.

*Msg.bin* displays some message boxes and lets you open the text file created by *File.bin* is Notepad.

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/Raffy27/Funky/blob/master/LICENSE) file for details. For the dependencies, all rights belong to their respective owners. These should be used according to their respective licenses.
