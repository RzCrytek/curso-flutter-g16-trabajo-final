import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:primo_secreto_app/widgets/common/broken_image_widget.dart';
import 'package:primo_secreto_app/models/wishlist_model.dart';
import 'package:primo_secreto_app/utils/ui_utils.dart';

class WishItemWidget extends StatelessWidget {
  final WishItemModel item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WishItemWidget({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  void _showImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: brokenImage,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: "Editar",
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: "Eliminar",
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline),
                  ),
              ],
            ),
            if (item.description != null) Text(item.description!),
            if (item.images.isNotEmpty) ...[
              SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.images.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final image = item.images[index];
                    return GestureDetector(
                      onTap: () => _showImage(context, image.url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          image.url,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: brokenImageOf(96),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            for (final link in item.links)
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: link.url));
                  if (context.mounted) {
                    showMessage(context, "Copiamos el enlace.");
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          link.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Icon(Icons.copy, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
