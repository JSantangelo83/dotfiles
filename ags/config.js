const entry = App.configDir + '/src/main.ts'

try {
    Utils.execAsync([
        'bun', 'build', entry,
        '--outfile', App.configDir + '/dist/main.js',
        '--external', 'resource://*',
        '--external', 'gi://*',
    ]).catch(console.error).then(() => {
        import(`file://${App.configDir}/dist/main.js`).catch(console.error)
    })
} catch (error) {
    console.error(error)
}