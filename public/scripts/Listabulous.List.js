$(document).ready(function () {
    List.Initialize();
});

var List = new Object;

List.Initialize = function () {
    List.InitializeListItemEntry();
    List.InitializeListItemEvents();
    $(".ListItem").linkify();
    List.SortItems();
    List.UpdateWindowTitle();
};

List.InitializeListItemEntry = function () {
    var listItemEntry = $("#ListItemEntry");
    listItemEntry.val(""); //stops firefox from adding the value in again :/
    listItemEntry.watermark("« add a new task", "Prompt");

    listItemEntry.keyup(function (event) {
        if (event.keyCode == 13 || event.keyCode == 10) {
            var listItemEntry = $(this);
            if (listItemEntry.val() != "") {
                var colour = $("#ChooseDefaultColour").css("background-color");

                List.ApiHtml("AddListItem", { "text": listItemEntry.val(), "colour": colour }, function (response) {
                    listItemEntry.removeClass("Loading");

                    if (response) {
                        var listItemContainer = $("#ListItemContainer");
                        var listItem = $(response);
                        listItem.linkify();
                        listItemContainer.append(listItem);
                        List.SortItems();
                        listItem.fadeIn();
                        List.UpdateWindowTitle();
                    }
                });

                listItemEntry.addClass("Loading");
                listItemEntry.val("");
            }
        }
    });
};
List.InitializeListItemEvents = function () {
    $("#ChooseDefaultColour").live("click", function () {
        List.ChooseDefaultColour_Click($(this));
    });
    $(".ListItemTitle").live("click", function (event) {
        if ($(event.originalTarget).is("a") == false) {
            List.ListItemTitle_Click($(this));
        }
    });
    $(".ListItem .ChooseListItemColour").live("click", function () {
        List.ChooseListItemColour_Click($(this));
    });
    $(".SelectColour").live("click", function () {
        List.SelectColour_Click($(this));
    });
    $(".DeleteListItem").live("click", function () {
        List.DeleteListItem_Click($(this));
    });
};
List.GetListItemId = function (listItem) {
    return listItem.find(".ListItemId").attr("value");
};

List.ChooseDefaultColour_Click = function (sender) {
    var colourPicker = $("#ColourPicker");
    if (colourPicker.is(":visible") && colourPicker.data("selectedEntryTextBox") == true) {
        colourPicker.fadeOut();
    } else {
        colourPicker.data("selectedListItem", null);
        colourPicker.data("selectedEntryTextBox", true);

        var newOffset = sender.offset();
        newOffset.left = newOffset.left + sender.width();

        colourPicker.css({ left: newOffset.left, top: newOffset.top });
        colourPicker.hide();
        colourPicker.fadeIn();
    }
};
List.ListItemTitle_Click = function (sender) {
    var listItem = sender.parent();

    listItem.toggleClass("Complete");

    var id = List.GetListItemId(listItem);
    var complete = listItem.hasClass("Complete");
    List.ApiJson("MarkListItemComplete", { "id": id, "complete": complete });
    List.UpdateWindowTitle();
};

List.ChooseListItemColour_Click = function (sender) {
    var listItem = sender.parent();

    var colourPicker = $("#ColourPicker");
    if (colourPicker.is(":visible") && List.GetListItemId(listItem) == List.GetListItemId(colourPicker.data("selectedListItem"))) {
        colourPicker.fadeOut();
    } else {
        colourPicker.data("selectedListItem", listItem);
        colourPicker.data("selectedEntryTextBox", false);

        var newOffset = sender.offset();
        newOffset.left = newOffset.left + sender.width();

        colourPicker.css({ left: newOffset.left, top: newOffset.top });
        colourPicker.hide();
        colourPicker.fadeIn();
    }
};
List.DeleteListItem_Click = function (sender) {
    var listItem = sender.parent();

    var id = List.GetListItemId(listItem);
    List.ApiJson("DeleteListItem", { "id": id });
    listItem.remove();
    List.UpdateWindowTitle();
};
List.SelectColour_Click = function (sender) {
    var colour = sender.css("background-color");
    var colourPicker = $("#ColourPicker");

    if (colourPicker.data("selectedEntryTextBox")) {
        $("#ChooseDefaultColour").css("background-color", colour);
        var listItemEntry = $("#ListItemEntry");
        listItemEntry.focus();
        List.ApiJson("SetUserDefaultColour", { "colour": colour });
    } else if (colourPicker.data("selectedListItem")) {
        var selectedListItem = colourPicker.data("selectedListItem");
        selectedListItem.find(".ChooseListItemColour").css("background-color", colour);
        List.SortItems();

        List.ApiJson("SetListItemColour", { "id": List.GetListItemId(selectedListItem), "colour": colour.toString() });
    }

    colourPicker.fadeOut();
};
List.SortItems = function () {
    var list = $("#ListItemContainer");

    var listItems = list.children(".ListItem").get();

    listItems.sort(function (a, b) {
        var compA = $(a).find(".ListItemTitle").text().toUpperCase();
        var compB = $(b).find(".ListItemTitle").text().toUpperCase();
        return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
    });
    //    listItems.sort(function (a, b) {
    //        var compA = $(a).hasClass("Complete") ? 1 : 0;
    //        var compB = $(b).hasClass("Complete") ? 1 : 0;
    //        return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
    //    });
    listItems.sort(function (a, b) {
        var compA = $(a).find(".ChooseListItemColour").css("background-color");
        var compB = $(b).find(".ChooseListItemColour").css("background-color");
        return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
    });


    $.each(listItems, function (index, item) { list.append(item); });
};
List.UpdateWindowTitle = function () {
    var listItemCount = $(".ListItem").length;
    var completeItemCount = $(".ListItem.Complete").length;
    var incompleteItemCount = listItemCount - completeItemCount;
    if (incompleteItemCount > 0) {
        document.title = $.format("{0} item{1} - Listabulous", incompleteItemCount, listItemCount == 1 ? "" : "s");
    } else {
        document.title = "Listabulous";
    }

};


List.ApiHtml = function (methodName, args, callback) {
    if (args) {
        //the model binder doesn't support the new way of serializing parameters so we use the old behaviour:
        args = $.param(args, true);
    }
    $.post("/ListApi/" + methodName, args, callback);
};

List.ApiJson = function (methodName, args, callback) {
    if (args) {
        //the model binder doesn't support the new way of serializing parameters so we use the old behaviour:
        args = $.param(args, true);
    }
    $.post("/ListApi/" + methodName, args, callback, "json");
};
