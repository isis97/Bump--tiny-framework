//import '../node_modules/requirejs/require.js';

require.config({
    baseUrl: "./bin",
    shim: {
      "bootstrap-css": {
        "deps": ['jquery']
      }
    },
    paths: {
        /* wire:js */
    }
});