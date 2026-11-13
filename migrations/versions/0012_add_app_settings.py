"""Add a small key/value settings table.

Holds app state that must survive serverless cold starts where the filesystem
is read-only — notably the Gmail OAuth token, which previously lived in a local
file. Idempotent: skips creation if the table already exists (prod creates
tables via create_all at boot).

Revision ID: 0012_add_app_settings
Revises: 0011_allow_multiple_tasks_per_item
"""

from typing import Optional, Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0012_add_app_settings"
down_revision: Optional[str] = "0011_allow_multiple_tasks_per_item"
branch_labels: Optional[Union[str, Sequence[str]]] = None
depends_on: Optional[Union[str, Sequence[str]]] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "app_settings" in inspector.get_table_names():
        return
    op.create_table(
        "app_settings",
        sa.Column("key", sa.Text(), primary_key=True),
        sa.Column("value", sa.Text(), nullable=True),
        sa.Column("updated_at", sa.Text(), nullable=False),
    )


def downgrade() -> None:
    raise RuntimeError("Downgrade is disabled for this project.")
