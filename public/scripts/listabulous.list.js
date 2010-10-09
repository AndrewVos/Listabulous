$(document).ready(function()
{
    List.initialize();
});

var List = {
    initialize: function()
    {
        this.listItemContainer = $("#ListItemContainer");
        this.listItemEntry = $("#ListItemEntry");
        this.colourPicker = $("#ColourPicker");

        this.initializeTextBox();
        this.initializeEvents();
        this.sortItems();
        this.updateWindowTitle();
        $(".ListItem").linkify();
    },

    initializeTextBox: function()
    {
        this.listItemEntry.watermark("« add a new task", "Prompt");

        this.listItemEntry.keyup(function(event) {
            if (event.keyCode == 13 || event.keyCode == 10) {
                if (this.listItemEntry.val() != "") {
                    $.post("/api/add-list-item", {
                        "text": this.listItemEntry.val(),
                        "colour": this.getDefaultColour()
                    },
                    function(response) {
                        this.listItemEntry.removeClass("Loading");

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

                    this.listItemEntry.addClass("Loading");
                    this.listItemEntry.val("");
                }
            }
        });
    },

    getDefaultColour: function()
    {
        return $("#ChooseDefaultColour").css("background-color");
    },

    initializeEvents: function()
    {
        $(document).click(function(event) {
            List.document_Click($(this), event);
        });

        $("#ChooseDefaultColour").live("click",
        function() {
            List.chooseDefaultColour_Click($(this));
        });

        $(".ListItemTitle").live("click",
        function() {
            List.listItemTitle_Click($(this));
        });

        $(".ChooseListItemColour").live("click",
        function() {
            List.chooseListItemColour_Click($(this));
        });

        $(".SelectColour").live("click",
        function() {
            List.selectColour_Click($(this));
        });

        $(".DeleteListItem").live("click",
        function() {
            List.deleteListItem_Click($(this));
        });
    },

    document_Click: function(sender, event)
    {
		this.colourPicker.hide();
    },

    chooseDefaultColour_Click: function(sender)
    {
        this.showColourPicker(sender.offset().left + sender.width(), sender.offset().top)
    },

    listItemTitle_Click: function(sender)
    {
        var listItem = sender.parent();
        listItem.toggleClass("Complete");

        var id = this.getListItemId(listItem);
        var complete = listItem.hasClass("Complete");

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
            $("#ChooseDefaultColour").css("background-color", colour);
            var listItemEntry = $("#ListItemEntry");
            listItemEntry.focus();
            $.post("/api/set-user-default-colour", {
                "default_colour": colour
            },
            null, "json");
        }
        else
        {
            selectedListItem.find(".ChooseListItemColour").css("background-color", colour);
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
    },

    getListItemId: function(listItem)
    {
        return listItem.find(".ListItemId").attr("value");
    },

    showColourPicker: function(x, y, selectedListItem)
    {
        if (selectedListItem === undefined) selectedListItem = null

        this.colourPicker.data("selectedListItem", selectedListItem);
        this.colourPicker.css({
            left: x,
            top: y
        });
        this.colourPicker.hide();
        this.colourPicker.fadeIn();
    },

    sortItems: function()
    {
        var listItems = this.listItemContainer.children(".ListItem").get();

        listItems.sort(function(a, b)
        {
            var compA = $(a).find(".ListItemTitle").text().toUpperCase();
            var compB = $(b).find(".ListItemTitle").text().toUpperCase();
            return (compA < compB) ? -1: (compA > compB) ? 1: 0;
        });
        listItems.sort(function(a, b)
        {
            var compA = $(a).find(".ChooseListItemColour").css("background-color");
            var compB = $(b).find(".ChooseListItemColour").css("background-color");
            return (compA < compB) ? -1: (compA > compB) ? 1: 0;
        });

        this.listItemContainer.append(listItems);
    },

    updateWindowTitle: function()
    {
        var listItemCount = $(".ListItem").length;
        var completeItemCount = $(".ListItem.Complete").length;
        var incompleteItemCount = listItemCount - completeItemCount;
        if (incompleteItemCount > 0)
        {
            document.title = $.format("{0} item{1} - Listabulous", incompleteItemCount, listItemCount == 1 ? "": "s");
        }
        else
        {
            document.title = "Listabulous";
        }
    }
}