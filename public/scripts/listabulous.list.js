$(document).ready(function () {
	List.initializeListItemEntry();
	List.initializeListItemEvents();
	$(".ListItem").linkify();
	List.sortItems();
	List.UpdateWindowTitle();
});

var List = new Object;

List.initializeListItemEntry = function () {
	var listItemEntry = $("#ListItemEntry");
	listItemEntry.val(""); //stops firefox from adding the value in again :/
	listItemEntry.watermark("« add a new task", "Prompt");

	listItemEntry.keyup(function (event) {
		if (event.keyCode == 13 || event.keyCode == 10) {
			var listItemEntry = $(this);
			if (listItemEntry.val() != "") {
				var colour = $("#ChooseDefaultColour").css("background-color");

				List.ApiHtml("add-list-item", { "text": listItemEntry.val(), "colour": colour }, function (response) {
					listItemEntry.removeClass("Loading");

					if (response) {
						var listItemContainer = $("#ListItemContainer");
						var listItem = $(response);
						listItem.linkify();
						listItemContainer.append(listItem);
						List.sortItems();
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

List.initializeListItemEvents = function () {
	$(document).click(function(event) {
		var originalTarget = $(event.originalTarget)
		
		if (originalTarget.is("#ChooseDefaultColour, .ChooseListItemColour") == false)
		{
			var colourPicker = $("#ColourPicker");
			colourPicker.fadeOut()
		}
	});
	$("#ChooseDefaultColour").live("click", function() {
		var sender = $(this);
		var newOffset = sender.offset();
		newOffset.left = newOffset.left + sender.width();
		List.showColourPicker(newOffset.left, newOffset.top)		
	});
	$(".ListItemTitle").live("click", function() {
		var sender = $(this);		
		var listItem = sender.parent();
		listItem.toggleClass("Complete");

		var id = List.GetListItemId(listItem);
		var complete = listItem.hasClass("Complete");
		
		$.post("/api/mark-list-item-complete", { "id": id, "complete": complete }, null, "json");
		List.UpdateWindowTitle();
	});
	$(".ListItem .ChooseListItemColour").live("click", function() {
		var sender = $(this);
		var listItem = sender.parent();
		var newOffset = sender.offset();
		newOffset.left = newOffset.left + sender.width();
		List.showColourPicker(newOffset.left, newOffset.top, listItem)
	});
	$(".SelectColour").live("click", function() {
		var sender = $(this);
		var colour = sender.css("background-color");
		var colourPicker = $("#ColourPicker");
		var selectedListItem = colourPicker.data("selectedListItem");

		if (selectedListItem == null) {
			$("#ChooseDefaultColour").css("background-color", colour);
			var listItemEntry = $("#ListItemEntry");
			listItemEntry.focus();
			$.post("/api/set-user-default-colour", { "default_colour": colour }, null, "json");
		} else {
			selectedListItem.find(".ChooseListItemColour").css("background-color", colour);
			List.sortItems();
			$.post("/api/set-list-item-colour", { "id": List.GetListItemId(selectedListItem), "colour": colour.toString() }, null, "json");
		}
	});
	$(".DeleteListItem").live("click", function() {
		var sender = $(this);
		var listItem = sender.parent();
		var id = List.GetListItemId(listItem);
		
		$.post("/api/delete-list-item", { "id": id }, null, "json");		
		listItem.remove();
		List.UpdateWindowTitle();
	});
};

List.GetListItemId = function (listItem) {
	return listItem.find(".ListItemId").attr("value");
};

List.showColourPicker = function(x, y, selectedListItem) {
	if (selectedListItem === undefined) selectedListItem = null

	var colourPicker = $("#ColourPicker");	
	colourPicker.data("selectedListItem", selectedListItem);
	colourPicker.css({ left: x, top: y });
	colourPicker.hide();
	colourPicker.fadeIn();
};

List.sortItems = function () {
	var list = $("#ListItemContainer");

	var listItems = list.children(".ListItem").get();

	listItems.sort(function (a, b) {
		var compA = $(a).find(".ListItemTitle").text().toUpperCase();
		var compB = $(b).find(".ListItemTitle").text().toUpperCase();
		return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
	});
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
	$.post("/api/" + methodName, args, callback);
};