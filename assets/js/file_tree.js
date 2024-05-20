document.addEventListener("DOMContentLoaded", function() {
    function renderFileTree(container, nodes) {
      nodes.forEach(node => {
        const element = document.createElement('div');
        element.classList.add('file-tree-node');
        element.textContent = node.name;
  
        if (node.type === 'directory') {
          element.classList.add('directory');
          const childrenContainer = document.createElement('div');
          childrenContainer.classList.add('children');
          renderFileTree(childrenContainer, node.children);
          element.appendChild(childrenContainer);
        } else {
          element.classList.add('file');
        }
  
        container.appendChild(element);
      });
    }
  
    const fileTreeContainer = document.getElementById('file-tree');
    renderFileTree(fileTreeContainer, fileTreeData);
  });

  //STUFF
  
//   function buildFileTree(element, tree) {
//     const ul = document.createElement('ul');
//     element.appendChild(ul);

//     tree.forEach(child => {
//         const li = document.createElement('li');
//         ul.appendChild(li);

//         const button = document.createElement('button');
//         button.textContent = child.name;
//         li.appendChild(button);

//         if (child.type === 'dir') {
//             var expanded = false;
//             button.addEventListener('click', () => {
//                 expanded = !expanded;
//                 if (expanded) {
//                     // Check if the child nodes have already been created
//                     if (!li.querySelector('ul')) {
//                         buildFileTree(li, child.children);
//                     }
//                 } else {
//                     const nestedUl = li.querySelector('ul');
//                     if (nestedUl) {
//                         li.removeChild(nestedUl); // Corrected line
//                     }
//                 }
//             });
//         } else if (child.type === 'file') {
//             button.addEventListener('click', () => {
//                 console.log(child.path);
//             });
//         }
//     });
// }

// var obsidianFilesJson = '{{ site.data.obsidian_files_json | escape }}';
// var parsedObsidianFilesJson = JSON.parse(obsidianFilesJson.replace(/&quot;/g, '"'));

// document.addEventListener('DOMContentLoaded', () => {
//     const rootElement = document.getElementById('fileTree');
//     buildFileTree(rootElement, parsedObsidianFilesJson);
// });


// const fileTreeElement = document.getElementById('fileTree');
// createFileTree(fileTreeElement, tree);