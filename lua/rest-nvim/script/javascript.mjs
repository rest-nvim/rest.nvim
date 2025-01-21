try {
    const ctx = JSON.parse(`%s`);

    let jsonPath;
    try {
        let jsonPathModule = await import("jsonpath");
        jsonPath = function (...args) {
            return jsonPathModule.default.value(...args);
        };
    } catch (e) {
       console.log(`jsonpath not found please install \`npm install --prefix ${ctx._env.cwd}\``);
    }

    let client;
    if (ctx.client) {
        // empty table json encoded as array by lua
        ctx.client.global.data = Array.isArray(ctx.client.global.data) ? {} : ctx.client.global.data;

        client = {
            global: {
                data: ctx.client.global.data,
                get: function (key) {
                    return ctx.client.global.data[key];
                },
                set: function (key, value) {
                    ctx.client.global.data[key] = value;
                },
            },
        };
    }

    let response;
    if (ctx.response) {
    //https://www.jetbrains.com/help/idea/http-response-reference.html
        response = {
            body: ctx.response.body,
            headers: {
                valueOf: function(key) {
                  return ctx.response.headers[key]?.[0]
                },
                valuesOf: function(key) {
                  return ctx.response.headers[key]
                }
            },
            status: ctx.response.status.code,
            contentType: {
                mineType: ctx.response.headers["content-type"]?.[0]?.split(";")?.[0],
                charset: ctx.response.headers["content-type"]?.[0].split(";")?.[0]
            }
        }
    }

    const request = {
        variables: {
            get: function (key) {
                return ctx.request.variables[key];
            },
            set: function (key, value) {
                ctx.request.variables[key] = value;
            },
        }
    }

    ;(function(){ %s })();

    console.log("-ENV-");
    console.log(JSON.stringify(ctx));
} catch (error) {
    console.log(error);
    console.log("-ENV-");
    console.log("{}");
}
