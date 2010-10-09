$(document).ready(function()
 {
    List.initialize();
});

var List = {
    initialize: function()
    {
        List.listItemContainer = $("#ListItemContainer");
        List.listItemEntry = $("#ListItemEntry");
        List.colourPicker = $("#ColourPicker");

        List.initializeListItemEntryTextBox();
        List.initializeEvents();
        $(".ListItem").linkify();
        List.sortItems();
        List.updateWindowTitle();
    },

    initializeListItemEntryTextBox: function()
    {
        List.listItemEntry.watermark("« add a new task", "Prompt");

        List.listItemEntry.keyup(function(event) {
            if (event.keyCode == 13 || event.keyCode == 10) {
                if (List.listItemEntry.val() != "") {
                    $.post("/api/add-list-item", {
                        "text": List.listItemEntry.val(),
                        "colour": List.getDefaultColour()
                    },
                    function(response) {
                        List.listItemEntry.removeClass("Loading");

                        if (response)
                        {
                            var listItem = $(response);
                            listItem.linkify();
                            List.listItemContainer.append(listItem);
                            List.sortItems();
                            listItem.fadeIn();
                            List.updateWindowTitle();
                        }
                    });

                    List.listItemEntry.addClass("Loading");
                    List.listItemEntry.val("");
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
        var originalTarget = $(event.target);

        if (originalTarget == null || originalTarget.is("#ChooseDefaultColour, .ChooseListItemColour") == false)
        {
            this.colourPicker.fadeOut()
        }
    },

    chooseDefaultColour_Click: function(sender)
    {
        var newOffset = sender.offset();
        newOffset.left = newOffset.left + sender.width();
        this.showColourPicker(newOffset.left, newOffset.top)
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
        var newOffset = sender.offset();
        newOffset.left = newOffset.left + sender.width();
        this.showColourPicker(newOffset.left, newOffset.top, listItem)
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