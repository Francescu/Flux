import Flux

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

do {
    let file = try File(path: "/Users/paulofaria/hello.txt", mode: .Read)
//    let file = try File(fileDescriptor: STDIN_FILENO)
    let data = try file.read()
    print(try String(data: data))
} catch {
    print(error)
}