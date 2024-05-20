function buildFileTree(element, tree) {
  const ul = document.createElement('ul');
  element.appendChild(ul);

  tree.forEach(child => {
    const li = document.createElement('li');
    ul.appendChild(li);

    const button = document.createElement('button');
    button.textContent = child.name;
    li.appendChild(button);

    if (child.type === 'dir') {
      li.classList.add('dir');
      const svgCollapsed = '<svg class="w-6 h-6 text-gray-800 dark:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24"><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m9 5 7 7-7 7"/></svg>';
      const svgExpanded = '<svg class="w-6 h-6 text-gray-800 dark:text-white" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24"><path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m19 9-7 7-7-7"/></svg>';
      button.innerHTML = svgCollapsed + button.textContent;

      var expanded = false;
      button.addEventListener('click', () => {
        expanded = !expanded;
        button.innerHTML = (expanded ? svgExpanded : svgCollapsed) + button.textContent;

        if (expanded) {
          // Check if the child nodes have already been created
          if (!li.querySelector('ul')) {
            buildFileTree(li, child.children);
          }
        } else {
          const nestedUl = li.querySelector('ul');
          if (nestedUl) {
            li.removeChild(nestedUl);
          }
        }
      });
    } else if (child.type === 'file') {
      li.classList.add('file');
      button.addEventListener('click', () => {
        console.log(child.path);
      });
    }
  });
}


var obsidianFilesJson = '{{ site.data.obsidian_files_json | escape }}';
var parsedObsidianFilesJson = JSON.parse(obsidianFilesJson.replace(/&quot;/g, '"'));

function sortObsidianFiles(tree) {
  tree.sort((a, b) => {
    if (a.type === 'dir' && b.type === 'file') {
      return -1;
    } else if (a.type === 'file' && b.type === 'dir') {
      return 1;
    } else {
      return a.name.localeCompare(b.name);
    }
  });
  tree.forEach(child => {
    if (child.type === 'dir') {
      sortObsidianFiles(child.children);
    }
  });
  return tree;
}

document.addEventListener('DOMContentLoaded', () => {
  const rootElement = document.getElementById('file-tree');
  const sortedFiles = sortObsidianFiles(parsedObsidianFilesJson);
  buildFileTree(rootElement, sortedFiles);
});
console.log(parsedObsidianFilesJson);
console.log("DIR root " + '{{ site.obsidian_vault | escape }}')