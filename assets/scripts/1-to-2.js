function convert() {
    var oldConfigText = document.getElementById("old-config").value;
    if(!oldConfigText) { return; }

    var actionLogContainer = document.getElementById("action-log");
    function log(text) {
      actionLogContainer.innerHTML += text + "\n";
    }

    var config = toml.parse(oldConfigText);

    // Mangle the old config

    log("Processing the <strong>[settings]</strong> section");

    // Default template options
    default_template = config.settings.default_template;
    if(default_template) {
        config.settings.default_template_file = default_template;
        delete config.settings.default_template;
        log("Deprecated option <strong>default_template</strong> renamed to <strong>default_template_file</strong>")
    }

    content_selector = config.settings.content_selector;
    if(content_selector) {
        config.settings.default_content_selector = content_selector;
        delete config.settings.content_selector;
        log("Deprecated option <strong>content_selector</strong> renamed to <strong>default_content_selector</strong>")
    }

    log("");

    // Index settings

    if(!("index" in config)) {
        log("Creating an <strong>[index]</strong> section");
        config.index = {}
    }
    else {
        log("Processing the <strong>[index]</strong> section")
    }

    if(config.index.newest_entries_first) {
        config.index.sort_descending = config.index.newest_entries_first;
        delete config.index.newest_entries_first;
        log("Deprecated option <strong>newest_entries_first</strong> renamed to <strong>sort_descending</strong>");
    }

    // Convert index.index_item_template and index.index_selector to an explicit view
    if(config.index.use_default_view) {
        log("<strong>use_default_view</strong> is true, but there is no built-in default view anymore: a default view will be created");

        log("Removing obsolete option <strong>use_default_view</strong>");
        delete config.index.use_default_view;

        if(!("views" in config.index)) {
            config.index.views = {}
        }

        if(config.index.views.default) {
            log("Warning: overwriting your existing [index.views.default]!");
        }

        log("Creating <strong>[index.views.default]</strong> table");
        config.index.views.default = {}

        if("index_item_template" in config.index) {
            log("Moving <strong>index_item_template</strong> to <strong>index.views.default.index_item_template</strong>")
            config.index.views.default.index_item_template = config.index.index_item_template;
        } else {
            // Old built-in default
            log("<strong>index_item_template</strong> is not set, setting to <strong>index.views.default.index_item_template</strong> to the old built-in default");
            config.index.views.default.index_item_template = "<div> <a href=\"{{url}}\">{{{title}}}</a> </div>";
        }

        if("index_selector" in config.index) {
            log("Moving <strong>index_selector</strong> to <strong>index.views.default.selector</strong>");
            config.index.views.default.selector = config.index.index_selector;
        } else {
            // Old built-in default
            log("<strong>index_selector</strong> is not set, setting to <strong>index.views.default.selector</strong> to the old built-in default");
            config.index.views.default.selector = "body";
        }
    } else {
        log("Since <strong>use_default_view</strong> is not set to true, <strong>index_selector</strong> and <strong>index_item_template</strong> can be removed");
    }
    log("Removing the now unnecessary <strong>index_selector</strong> and <strong>index_item_template</strong> options");
    delete config.index.index_selector;
    delete config.index.index_item_template;

    log("Removing the obsolete <strong>use_default_view</strong> option");
    delete config.index.use_default_view;

    // Rename [index.custom_fields] to [index.fields]
    if("custom_fields" in config.index) {
        log("Renaming <strong>[index.custom_fields]</strong> table to <strong>[index.fields]</strong>");
        config.index.fields = config.index.custom_fields;
        delete config.index.custom_fields;
    }

    var oldIndexFields = [
      {name: "title", value: "h1"},
      {name: "excerpt", value: "p"},
      {name: "title", value: "h1"},
      {name: "date", value: "time"},
      {name: "author", value: "#author"}
    ];

    if(!("fields" in config.index)) { config.index.fields = {} }

    oldIndexFields.forEach(function (field) {
        var fieldName = field.name;
        var oldFieldName = `index_${fieldName}_selector`;
        console.log(oldFieldName);
        console.log(config.index[oldFieldName]);
        if(oldFieldName in config.index) {
            log(`Converting obsolete field <strong>${oldFieldName}</strong> to <strong>[index.fields.${fieldName}]</strong>`);
            config.index.fields[fieldName] = {};
            config.index.fields[fieldName].selector = config.index[oldFieldName];
            delete config.index[oldFieldName];
        }
    });

    window.views = config.index.views;
    if(config.index.views) {
        for (const key in config.index.views) {
            view = config.index.views[key];
            if(view.index_item_template) {
                log("Replacing triple braces with double braces in an <strong>index_item_template</strong>");
                view.index_item_template = view.index_item_template.replaceAll("{{{", "{{");
                view.index_item_template = view.index_item_template.replaceAll("}}}", "}}");
            }
        }
    }

    log("Inserting <strong>sort_by = \"date\"</strong> in the index settings");
    config.index.sort_by = "date";

    // Output the new config
    var outputContainer = document.getElementById("new-config");
    var newConfigText = toml.print(config, 4, true);

    outputContainer.innerHTML = "";
    outputContainer.appendChild(document.createTextNode(newConfigText));
}
