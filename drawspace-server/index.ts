// Allows you to precompile ES6 syntax
require('@babel/register')({
    plugins: ['dynamic-import-node'],
});

// Run server
require('./src/server');
