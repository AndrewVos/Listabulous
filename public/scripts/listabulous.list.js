var List = {
    initialize: function()
    {
        this.listItemContainer = $("#list_item_container");
        this.listItemEntry = $("#list_item_entry");
        this.colourPicker = $("#colour_picker");

        this.initializeEvents();
        this.initializeTextBox();
        this.sortItems();
        this.updateWindowTitle();
        $(".list_item").linkify();
    },

    initializeTextBox: function()
    {
        this.listItemEntry.watermark("« add a new task", "prompt");

        this.listItemEntry.keyup(function(event) {
            if (event.keyCode == 13 || event.keyCode == 10) {
                if (this.listItemEntry.val() != "") {
                    $.post("/api/add-list-item", {
                        "text": this.listItemEntry.val(),
                        "colour": this.getDefaultColour()
                    },
                    function(response) {
                        this.listItemEntry.removeClass("loading");

                        if (response)
                        {
                            var listItem = $(response);
                            this.listItemContainer.append(listItem);
                            this.sortItems();
                            this.updateWindowTitle();
                            listItem.linkify();
                            listItem.fadeIn();
                        }
                    });

                    this.listItemEntry.addClass("loading");
                    this.listItemEntry.val("");
                }
            }
        });
    },

    getDefaultColour: function()
    {
        return $("#choose_default_colour").css("background-color");
    },

    initializeEvents: function()
    {
        $("#choose_default_colour").live("click",
        function() {
            List.chooseDefaultColour_Click($(this));
        });

        $(".list_item_title").live("click",
        function() {
            List.listItemTitle_Click($(this));
        });

        $(".choose_list_item_colour").live("click",
        function() {
            List.chooseListItemColour_Click($(this));
        });

        $(".select_colour").live("click",
        function() {
            List.selectColour_Click($(this));
        });

        $(".delete_list_item").live("click",
        function() {
            List.deleteListItem_Click($(this));
        });
    },

    getListItemId: function(listItem)
    {
        return listItem.find(".list_item_id").attr("value");
    },

    showColourPicker: function(x, y, selectedListItem)
    {
        if (selectedListItem === undefined) selectedListItem = null

        this.colourPicker.data("selectedListItem", selectedListItem);
        this.colourPicker.css({
            left: x,
            top: y
        });

        $(document).one("click",
        function(event)
        {
            var eventTarget = $(event.target);
            if (eventTarget.is(".choose_list_item_colour, #choose_default_colour") == false)
            {
                List.colourPicker.fadeOut();
            }
        });

        this.colourPicker.fadeIn();
    },

    sortItems: function()
    {
        var listItems = this.listItemContainer.children(".list_item").get();

        listItems.sort(function(a, b)
        {
            var compA = $(a).find(".list_item_title").text().toUpperCase();
            var compB = $(b).find(".list_item_title").text().toUpperCase();
            return (compA < compB) ? -1: (compA > compB) ? 1: 0;
        });
        listItems.sort(function(a, b)
        {
            var compA = $(a).find(".choose_list_item_colour").css("background-color");
            var compB = $(b).find(".choose_list_item_colour").css("background-color");
            return (compA < compB) ? -1: (compA > compB) ? 1: 0;
        });

        this.listItemContainer.append(listItems);
    },

    updateWindowTitle: function()
    {
        var listItemCount = $(".list_item").length;
        var completeItemCount = $(".list_item.complete").length;
        var incompleteItemCount = listItemCount - completeItemCount;
        if (incompleteItemCount > 0)
        {
            document.title = $.format("{0} item{1} - Listabulous", incompleteItemCount, listItemCount == 1 ? "": "s");
        }
        else
        {
            document.title = "Listabulous";
        }
    },

    chooseDefaultColour_Click: function(sender)
    {
        this.showColourPicker(sender.offset().left + sender.width(), sender.offset().top)
    },

    listItemTitle_Click: function(sender)
    {
        var listItem = sender.parent();
        listItem.toggleClass("complete");

        var id = this.getListItemId(listItem);
        var complete = listItem.hasClass("complete");

        $.post("/api/mark-list-item-complete", {
            "id": id,
            "complete": complete
        },
        null, "json");
        this.updateWindowTitle();
    },

    chooseListItemColour_Click: function(sender)
    {
        var listItem = sender.parent();
        this.showColourPicker(sender.offset().left + sender.width(), sender.offset().top, listItem)
    },

    selectColour_Click: function(sender)
    {
        var colour = sender.css("background-color");
        var selectedListItem = this.colourPicker.data("selectedListItem");

        if (selectedListItem == null)
        {
            $("#choose_default_colour").css("background-color", colour);
            this.listItemEntry.focus();
            $.post("/api/set-user-default-colour", {
                "default_colour": colour
            },
            null, "json");
        }
        else
        {
            selectedListItem.find(".choose_list_item_colour").css("background-color", colour);
            this.sortItems();
            $.post("/api/set-list-item-colour", {
                "id": this.getListItemId(selectedListItem),
                "colour": colour.toString()
            },
            null, "json");
        }
    },

    deleteListItem_Click: function(sender)
    {
        var listItem = sender.parent();
        var id = this.getListItemId(listItem);

        listItem.remove();
        this.updateWindowTitle();
        $.post("/api/delete-list-item", {
            "id": id
        },
        null, "json");
    }
}