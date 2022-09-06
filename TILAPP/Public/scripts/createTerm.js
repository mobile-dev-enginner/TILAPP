// Gets all the categories in the TIL application
$.ajax({
    url: "/api/categories",
    type: "GET",
    contentType: "application/json; charset=utf-8"
}).then(function (res) {
    var dataToReturn = [];
    for (var i = 0; i < res.length; i++) {
        var tagToTransform = res[i];
        var newTag = {
            id: tagToTransform["name"],
            text: tagToTransform["name"]
        };
    dataToReturn.push(newTag);
    }
    // Get the HTML element with the ID categories & call select2() on it.
    $("#categories").select2({
        placeholder: "Select Categories for the Terminology",
        tags: true,
        tokenSeparators: [','],
        data: dataToReturn
    });
});
