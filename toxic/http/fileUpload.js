$(function() {
	$('input[type=file]').closest('form').submit(function() {
		var $form = $(this);
		var $fileFields = $form.find('input[type=file]');
		var $buttons = $form.find('input[type=submit]');
		var ret = true;
		
		$fileFields.each(function(i, el) {
			if(this.files.length == 0)
				return;
			
			if(this.files[0].size > 64*1024)
			{
				alert('File is too big! Maximal file size is 64kB.');
				ret = false;
				return;
			}
			
			var $fileEl = $(this);
			var id = $fileEl.attr('id');
			
			var $hiddenFilename = $form.find('input[type=hidden][name=' + id + ']');
			if($hiddenFilename.length == 0)
			{
				$hiddenFilename = $('<input type="hidden" name="' + id + '" value="" />');
				$form.append($hiddenFilename);
			}
			
			var $hiddenContent = $form.find('input[type=hidden][name=' + id + '_content]');
			if($hiddenContent.length == 0)
			{
				$hiddenContent = $('<input type="hidden" name="' + id + '_content" value="" />');
				$form.append($hiddenContent);
			}
			
			$hiddenFilename.val(this.files[0].name);
			
			if($hiddenContent.val() != '')
				return; // already loaded
			
			// load file first
			ret = false;
			$buttons.prop('disabled', true);
			
			var reader = new FileReader();
			reader.onload = function(e)
			{
				var content = e.target.result;
				content = window.btoa(content);
				//content = JSON.stringify([content]);
				//alert('Uploading ' + content.length + ' bytes!');
				$hiddenContent.val(content);
				$buttons.prop('disabled', false);
				$form.submit();
			}
			reader.readAsBinaryString(this.files[0]);
		});
		
		return ret;
	});
});
