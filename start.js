var spawn = require("child_process").spawn;

console.log("** Starting Mongo...");

var db = spawn("/bin/niscud", [ "--fork", "--port", "4002", "--dbpath", "/var",
    "--noauth", "--bind_ip", "127.0.0.1", "--nohttpinterface", "--noprealloc",
    "--logpath", "/var/mongo.log" ], {
      stdio: "inherit"
    })

db.on("error", function (err) {
  console.error("Couldn't start Mongo: " + err.stack);
  process.exit(1);
});

db.on("exit", function (code, signal) {
  if (signal) {
    console.error("Mongo startup failed with signal: " + signal);
    process.exit(1);
  }
  if (code !== 0) {
    console.error("Mongo startup exited with error code: " + code);
    process.exit(1);
  }
  
  console.log("** Starting Meteor...");
  process.env.MONGO_URL="mongodb://127.0.0.1:4002/meteor";
  process.env.ROOT_URL="http://127.0.0.1:4000";
  process.env.PORT="4000";
  require("./main.js");
});

