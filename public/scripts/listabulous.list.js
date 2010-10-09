$(document).ready(function()
{
	List.initialize();
});

var List = {
	initialize : function()
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
		
	initializeListItemEntryTextBox : function ()
	{
		List.listItemEntry.watermark("« add a new task", "Prompt");

		List.listItemEntry.keyup(function(event) {
			if (event.keyCode == 13 || event.keyCode == 10) {
				if (List.listItemEntry.val() != "") {
					$.post("/api/add-list-item", { "text": List.listItemEntry.val(), "colour": List.getDefaultColour() }, function (response) {
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
	
	getDefaultColour : function()
	{
		return $("#ChooseDefaultColour").css("background-color");
	},
	
	initializeEvents : function()
	{
		$(document).click(function(event) {
			var originalTarget = $(event.originalTarget)

			if (originalTarget.is("#ChooseDefaultColour, .ChooseListItemColour") == false)
			{
				List.colourPicker.fadeOut()
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

			var id = List.getListItemId(listItem);
			var complete = listItem.hasClass("Complete");

			$.post("/api/mark-list-item-complete", { "id": id, "complete": complete }, null, "json");
			List.updateWindowTitle();
		});

		$(".ChooseListItemColour").live("click", function() {
			var sender = $(this);
			var listItem = sender.parent();
			var newOffset = sender.offset();
			newOffset.left = newOffset.left + sender.width();
			List.showColourPicker(newOffset.left, newOffset.top, listItem)
		});

		$(".SelectColour").live("click", function() {
			var sender = $(this);
			var colour = sender.css("background-color");
			var selectedListItem = List.colourPicker.data("selectedListItem");

			if (selectedListItem == null)
			{
				$("#ChooseDefaultColour").css("background-color", colour);
				var listItemEntry = $("#ListItemEntry");
				listItemEntry.focus();
				$.post("/api/set-user-default-colour", { "default_colour": colour }, null, "json");
			}
			else
			{
				selectedListItem.find(".ChooseListItemColour").css("background-color", colour);
				List.sortItems();
				$.post("/api/set-list-item-colour", { "id": List.getListItemId(selectedListItem), "colour": colour.toString() }, null, "json");
			}
		});

		$(".DeleteListItem").live("click", function() {
			var sender = $(this);
			var listItem = sender.parent();		
			var id = List.getListItemId(listItem);

			listItem.remove();	
			List.updateWindowTitle();		
			$.post("/api/delete-list-item", { "id": id }, null, "json");		
		});
	},
	
	getListItemId : function(listItem)
	{
		return listItem.find(".ListItemId").attr("value");
	},
	
	showColourPicker : function(x, y, selectedListItem)
	{
		if (selectedListItem === undefined) selectedListItem = null

		List.colourPicker.data("selectedListItem", selectedListItem);
		List.colourPicker.css({ left: x, top: y });
		List.colourPicker.hide();
		List.colourPicker.fadeIn();	
	},
	
	sortItems : function()
	{
		var listItems = List.listItemContainer.children(".ListItem").get();

		listItems.sort(function (a, b)
		{
			var compA = $(a).find(".ListItemTitle").text().toUpperCase();
			var compB = $(b).find(".ListItemTitle").text().toUpperCase();
			return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
		});
		listItems.sort(function (a, b)
		{
			var compA = $(a).find(".ChooseListItemColour").css("background-color");
			var compB = $(b).find(".ChooseListItemColour").css("background-color");
			return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
		});

		List.listItemContainer.append(listItems);
	},
	
	updateWindowTitle : function()
	{
		var listItemCount = $(".ListItem").length;
		var completeItemCount = $(".ListItem.Complete").length;
		var incompleteItemCount = listItemCount - completeItemCount;
		if (incompleteItemCount > 0)
		{
			document.title = $.format("{0} item{1} - Listabulous", incompleteItemCount, listItemCount == 1 ? "" : "s");
		}
		else
		{
			document.title = "Listabulous";
		}	
	}
}